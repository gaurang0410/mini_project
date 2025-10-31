// lib/screens/profile_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/firestore_service.dart';
import '../services/user_state.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<bool?> _showConfirmationDialog(BuildContext context, String title, String content) async {
    if (!context.mounted) return false;
    return showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              child: Text('Confirm', style: TextStyle(color: Colors.red.shade700)),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserState>(
      builder: (context, userState, child) {
        final AuthService authService = AuthService();
        final FirestoreService firestoreService = FirestoreService();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile & Settings'),
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            foregroundColor: Theme.of(context).colorScheme.primary,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: userState.isGuest
                ? _buildGuestProfile(context)
                : _buildUserProfile(context, userState, authService, firestoreService),
          ),
        );
      },
    );
  }

  Widget _buildGuestProfile(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.person_outline, size: 80, color: Colors.grey.shade400),
        const SizedBox(height: 20),
        Text(
          'You are browsing as a Guest',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          'Sign in or create an account to save your conversion history online and unlock more features.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: () {
            Navigator.pushNamed(context, '/login');
          },
          child: const Text('Login / Sign Up'),
        ),
      ],
    );
  }

  Widget _buildUserProfile(BuildContext context, UserState userState, AuthService authService, FirestoreService firestoreService) {
    final User? user = FirebaseAuth.instance.currentUser;
    final String uid = userState.currentUser!.uid;
    final String role = userState.currentUser!.role;
    final bool isVip = userState.isVip;

    String joinDate = 'N/A';
    if (user?.metadata.creationTime != null) {
      joinDate = DateFormat('dd MMMM yyyy').format(user!.metadata.creationTime!);
    }

    return Column(
      children: [
        _buildProfileHeader(context, user, joinDate),
        const SizedBox(height: 20),
        // --- THIS IS THE VIP STATUS WIDGET ---
        _buildStatusBadges(context, role, isVip),
        const SizedBox(height: 10),
        SelectableText(
          "User ID: $uid",
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        _buildStatsCard(context, uid),
        const SizedBox(height: 20),
        Text("User Controls", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        const Divider(thickness: 1),
        const SizedBox(height: 10),
        ListTile(
          leading: Icon(Icons.delete_sweep, color: Colors.orange.shade800),
          title: const Text('Clear Recent Searches'),
          subtitle: const Text('Removes local search history from THIS device only.'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
             final confirmed = await _showConfirmationDialog(
               context, 'Clear Recent Searches?',
               'This will permanently delete your recent search history stored locally on this device. Are you sure?'
             );
             if (confirmed == true && context.mounted) {
               try {
                   await DatabaseService.instance.clearRecentSearches();
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text('Local recent searches cleared!'), duration: Duration(seconds: 2)),
                   );
               } catch (e) {
                    if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error clearing local history: $e'), backgroundColor: Colors.red)
                        );
                    }
               }
             }
          },
        ),
         ListTile(
          leading: Icon(Icons.cloud_off, color: Colors.red.shade800),
          title: const Text('Clear ALL Online History'),
          subtitle: const Text('WARNING: Deletes ALL conversion history from your account.'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            final confirmed = await _showConfirmationDialog(
               context, 'Clear ALL Online History?',
               'WARNING: This action cannot be undone. It will permanently delete all conversion records saved to your account online across all devices. Are you sure?'
             );
              if (confirmed == true && context.mounted) {
               try {
                  await firestoreService.clearUserConversionHistory(uid);
                  ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text('Online conversion history cleared!'), duration: Duration(seconds: 2)),
                  );
               } catch (e) {
                  if (context.mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text('Error clearing online history: $e'), backgroundColor: Colors.red),
                     );
                  }
               }
             }
          },
        ),
        const Spacer(),
        _buildLogoutButton(context, authService),
         const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildStatusBadges(BuildContext context, String role, bool isVip) {
    final String displayRole = role.isEmpty ? 'User' : role[0].toUpperCase() + role.substring(1);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isVip ? Colors.amber.shade700 : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(isVip ? Icons.star : Icons.shield, size: 16, color: isVip ? Colors.white : Colors.grey.shade700),
              const SizedBox(width: 6),
              Text(
                isVip ? 'Premium VIP' : 'Standard User',
                style: TextStyle(fontWeight: FontWeight.bold, color: isVip ? Colors.white : Colors.grey.shade700),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: role == 'admin' ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(role == 'admin' ? Icons.admin_panel_settings : Icons.person, size: 16, color: role == 'admin' ? Colors.white : Colors.grey.shade700),
              const SizedBox(width: 6),
              Text(
                displayRole,
                style: TextStyle(fontWeight: FontWeight.bold, color: role == 'admin' ? Colors.white : Colors.grey.shade700),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(BuildContext context, User? user, String joinDate) {
     return Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey.shade200,
              child: Icon(Icons.account_circle, size: 50, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            Text(
              user?.email ?? 'No email available',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Joined: $joinDate',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        );
  }

  Widget _buildStatsCard(BuildContext context, String? userId) {
     return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatItem(
                  context: context,
                  icon: Icons.sync_alt,
                  label: 'Total Conversions',
                  value: StreamBuilder<QuerySnapshot>(
                    stream: userId == null ? null : FirebaseFirestore.instance
                        .collection('conversionHistory')
                        .where('userId', isEqualTo: userId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2));
                      }
                       if (!snapshot.hasData || snapshot.hasError || snapshot.data == null) {
                         print("Error fetching stats: ${snapshot.error}");
                         return Text('0', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold));
                       }
                      return Text(
                        (snapshot.data?.docs.length ?? 0).toString(),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
  }

  Widget _buildStatItem({required BuildContext context, required IconData icon, required String label, required Widget value}) {
     return Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 32),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
            const SizedBox(height: 4),
            DefaultTextStyle(
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.bold),
              child: value,
            ),
          ],
        );
  }

  Widget _buildLogoutButton(BuildContext context, AuthService authService) {
     return ElevatedButton.icon(
          onPressed: () async {
             final confirmed = await _showConfirmationDialog(
                 context, 'Logout?', 'Are you sure you want to log out?'
             );
             if (confirmed == true && context.mounted) {
                 try {
                     await authService.signOut();
                 } catch (e) {
                     print("Error during sign out: $e");
                     if (context.mounted) {
                         ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(content: Text('Error logging out: $e'), backgroundColor: Colors.red)
                         );
                     }
                 }
             }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent.withOpacity(0.1),
            foregroundColor: Colors.redAccent,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          icon: const Icon(Icons.logout),
          label: const Text('Logout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        );
  }
}