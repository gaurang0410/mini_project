import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/user_state.dart';
import 'login_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  Future<void> _deleteHistoryItem(String docId) async {
    await FirebaseFirestore.instance.collection('conversionHistory').doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    final userState = Provider.of<UserState>(context);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Online Conversion History')),
      body: userState.isGuest
          ? _buildGuestHistory(context)
          : _buildUserHistory(context, user!),
    );
  }

  Widget _buildGuestHistory(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.history_toggle_off, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 20),
            Text(
              'No History Available',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Sign in or create an account to save and view your online conversion history across all devices.',
              // --- FIX: Removed duplicate 'TextAlign:' ---
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
        ),
      ),
    );
  }

  Widget _buildUserHistory(BuildContext context, User user) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('conversionHistory')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No conversion history found.'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;
            
            String formattedDate = data['timestamp'] == null
                ? 'Date not available'
                : DateFormat('dd MMM yyyy, hh:mm a').format((data['timestamp'] as Timestamp).toDate());

            return Dismissible(
              key: Key(doc.id),
              direction: DismissDirection.endToStart,
              onDismissed: (direction) {
                _deleteHistoryItem(doc.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("History item deleted"),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              background: Container(
                color: Colors.redAccent,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                alignment: Alignment.centerRight,
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(
                    '${data['amount'].toStringAsFixed(2)} ${data['from']}  ➔  ${data['result'].toStringAsFixed(2)} ${data['to']}',
                    style: const TextStyle(fontWeight: FontWeight.bold)
                  ),
                  subtitle: Text(formattedDate),
                ),
              ),
            );
          },
        );
      },
    );
  }
}