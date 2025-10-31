// lib/screens/admin_panel_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/user_state.dart';
import 'feature_flag_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  
  // --- MODIFIED: Renamed _isLoading to be more specific ---
  bool _isActionLoading = false; // For VIP toggle, delete history, etc.
  
  // --- NEW: State variable to hold the live search query ---
  String _searchQuery = "";
  
  // --- REMOVED: _searchUser, _searchError, and old _isLoading ---

  UserModel? _selectedUser;
  final User? _admin = FirebaseAuth.instance.currentUser;
  Stream<QuerySnapshot>? _allUsersStream;

  @override
  void initState() {
    super.initState();
    _allUsersStream = _firestoreService.getAllUsersStream();
  }

  // Helper function to show confirmation dialogs
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

  // --- REMOVED: _searchUser() function is no longer needed ---

  // Helper function to select a user from the list
  void _selectUserFromList(DocumentSnapshot userDoc) {
    final user = UserModel.fromFirestore(userDoc, {});
    setState(() {
      _selectedUser = user;
    });
  }

  Future<void> _togglePremiumStatus() async {
    if (_selectedUser == null || _admin == null) return;
    final newStatus = !_selectedUser!.isPremium;
    setState(() => _isActionLoading = true);

    try {
      await _firestoreService.updateUserPremiumStatus(_selectedUser!.uid, newStatus);
      await _firestoreService.addAuditLog(
          adminUid: _admin!.uid,
          action: 'TOGGLE_PREMIUM',
          targetUserEmail: _selectedUser!.email,
          targetUid: _selectedUser!.uid,
          details: {'premium_status': newStatus}
      );

      setState(() {
         _selectedUser = UserModel(
            uid: _selectedUser!.uid, email: _selectedUser!.email,
            role: _selectedUser!.role, isPremium: newStatus,
            createdAt: _selectedUser!.createdAt,
            featureFlags: _selectedUser!.featureFlags
         );
      });

      if (_selectedUser!.uid == _admin!.uid && context.mounted) {
         Provider.of<UserState>(context, listen: false).refreshUserData();
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User ${_selectedUser!.email} premium status set to $newStatus')),
        );
      }
    } catch (e) {
       if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e'), backgroundColor: Colors.red),
        );
       }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _deleteUserOnlineHistory() async {
    if (_selectedUser == null || _admin == null) return;
    final confirmed = await _showConfirmationDialog(
      context,
      'Delete Online History?',
      'WARNING: This will permanently delete ALL ${_selectedUser!.email}\'s conversion history from the server. This cannot be undone. Are you sure?'
    );
    if (confirmed != true) return;
    setState(() => _isActionLoading = true);
    try {
      await _firestoreService.clearUserConversionHistory(_selectedUser!.uid);
      await _firestoreService.addAuditLog(
          adminUid: _admin!.uid,
          action: 'DELETE_USER_HISTORY',
          targetUserEmail: _selectedUser!.email,
          targetUid: _selectedUser!.uid,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully cleared all online history for ${_selectedUser!.email}.')),
        );
      }
    } catch (e) {
       if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting history: $e'), backgroundColor: Colors.red),
        );
       }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      // --- NEW: Added Stack to show loading overlay ---
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Section 1: App Controls ---
                Text("App Controls", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const Divider(thickness: 1),
                ListTile(
                  leading: Icon(Icons.flag, color: Theme.of(context).colorScheme.primary),
                  title: const Text('Manage Feature Flags'),
                  subtitle: const Text('Toggle app features on or off remotely.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const FeatureFlagsScreen()));
                  },
                ),
                const SizedBox(height: 20),

                // --- Section 2: User Management (Search) ---
                Text("User Management", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const Divider(thickness: 1),
                
                // --- MODIFIED: TextField now updates live ---
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search Users by Email',
                    // Show a clear button if text is entered, else show search icon
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _selectedUser = null; // Clear selection
                              });
                            },
                          )
                        : const Icon(Icons.search),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                      _selectedUser = null; // Clear selection when search changes
                    });
                  },
                ),
                const SizedBox(height: 10),

                // --- REMOVED: Old _isLoading and _searchError widgets ---
                
                // --- Section 3: Selected User Card (if any) ---
                if (_selectedUser != null)
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 20.0),
                    color: Colors.blue.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Theme.of(context).colorScheme.primary)
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Managing User:', style: Theme.of(context).textTheme.titleMedium),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => setState(() => _selectedUser = null),
                              )
                            ],
                          ),
                          const Divider(),
                          const SizedBox(height: 5),
                          Text('Email: ${_selectedUser!.email}'),
                          Text('UID: ${_selectedUser!.uid}'),
                          Text('Role: ${_selectedUser!.role}'),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Premium (VIP) Status:\n${_selectedUser!.isPremium ? "Active" : "Inactive"}'),
                              ElevatedButton(
                                onPressed: _togglePremiumStatus,
                                style: ElevatedButton.styleFrom(
                                   backgroundColor: _selectedUser!.isPremium ? Colors.orange : Colors.green),
                                child: Text(_selectedUser!.isPremium ? 'Revoke VIP' : 'Grant VIP'),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Text("Danger Zone", style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.red.shade700)),
                          const SizedBox(height: 10),
                          ListTile(
                            leading: Icon(Icons.cloud_off, color: Colors.red.shade700),
                            title: const Text('Delete ALL Online History'),
                            subtitle: const Text('Removes this user\'s conversion history from the server.'),
                            trailing: Icon(Icons.keyboard_arrow_right, color: Colors.red.shade700),
                            onTap: _deleteUserOnlineHistory,
                            tileColor: Colors.red.withOpacity(0.05),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Note: You cannot delete a user's 'Recent Searches' as that data is stored locally on their device, not on the server.",
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // --- Section 4: All Users List (Now Filtered) ---
                const SizedBox(height: 10),
                Text("All Signed-Up Users", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const Divider(thickness: 1),
                StreamBuilder<QuerySnapshot>(
                  stream: _allUsersStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("No users found."));
                    }

                    final users = snapshot.data!.docs;

                    // --- NEW: Live filtering logic ---
                    final filteredUsers = users.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final email = (data['email'] ?? '').toLowerCase();
                      return email.contains(_searchQuery);
                    }).toList();
                    // ---------------------------------

                    if (filteredUsers.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text("No users match your search."),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: filteredUsers.length, // Use filtered list
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final doc = filteredUsers[index]; // Use filtered list
                        final userModel = UserModel.fromFirestore(doc, {});
                        
                        String formattedDate = 'Joined: N/A';
                        if (userModel.createdAt != null) {
                          formattedDate = 'Joined: ${DateFormat('dd MMM yyyy').format(userModel.createdAt!.toDate())}';
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          color: _selectedUser?.uid == userModel.uid ? Colors.blue.shade100 : null,
                          child: ListTile(
                            leading: Icon(userModel.role == 'admin' ? Icons.admin_panel_settings : Icons.person),
                            title: Text(userModel.email, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("$formattedDate | Role: ${userModel.role}"),
                            trailing: Chip(
                              label: Text(userModel.isPremium ? 'VIP' : 'Standard'),
                              backgroundColor: userModel.isPremium ? Colors.amber.shade200 : Colors.grey.shade300,
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            ),
                            onTap: () {
                              _selectUserFromList(doc);
                              FocusScope.of(context).unfocus(); // Close keyboard
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          
          // --- NEW: Loading overlay for admin actions ---
          if (_isActionLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}