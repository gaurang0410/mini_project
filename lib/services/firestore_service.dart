// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Deletes all conversion history for a specific user ---
  Future<void> clearUserConversionHistory(String userId) async {
    final query = _db.collection('conversionHistory').where('userId', isEqualTo: userId);
    final snapshot = await query.get();

    if (snapshot.docs.isEmpty) {
      print("No online history found for user $userId. Nothing to delete.");
      return;
    }

    print("Found ${snapshot.docs.length} history items for user $userId. Deleting...");

    final WriteBatch batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    print("Successfully deleted all online history for user $userId.");
  }

  // --- Find User by Email ---
  Future<List<QueryDocumentSnapshot>> findUserByEmail(String email) async {
    QuerySnapshot snapshot = await _db
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    return snapshot.docs;
  }

  // --- Update User's Premium Status ---
  Future<void> updateUserPremiumStatus(String uid, bool isPremium) async {
    await _db.collection('users').doc(uid).update({
      'premium': isPremium,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // --- Update a Feature Flag ---
  Future<void> updateFeatureFlag(String flagName, bool newValue) async {
    await _db.collection('app_config').doc('features').set({
      flagName: newValue,
    }, SetOptions(merge: true)); // Use merge to avoid overwriting other flags
  }

  // --- Log Admin Actions ---
  Future<void> addAuditLog({
      required String adminUid,
      required String action,
      required String targetUserEmail,
      required String targetUid,
      Map<String, dynamic>? details,
  }) async {
      await _db.collection('audit_logs').add({
          'actorUid': adminUid,
          'action': action,
          'targetUserEmail': targetUserEmail,
          'targetUid': targetUid,
          'details': details ?? {},
          'timestamp': FieldValue.serverTimestamp(),
      });
  }

  // --- NEW FUNCTION: Get a stream of all users ---
  /// Returns a stream of all users, sorted by creation date.
  Stream<QuerySnapshot> getAllUsersStream() {
    return _db
        .collection('users')
        .orderBy('createdAt', descending: true) // Show newest users first
        .snapshots();
  }
}