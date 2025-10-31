import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String role;
  final bool isPremium;
  final Timestamp? createdAt;
  
  // --- NEW: Added featureFlags ---
  final Map<String, dynamic> featureFlags;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.isPremium,
    this.createdAt,
    this.featureFlags = const {}, // Default to empty map
  });

  // Factory constructor to create a UserModel from a Firestore document snapshot
  factory UserModel.fromFirestore(DocumentSnapshot doc, Map<String, dynamic> appFlags) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Merge app-wide flags
    final mergedFlags = {...appFlags};

    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      role: data['role'] ?? 'user',
      isPremium: data['premium'] ?? false,
      createdAt: data['createdAt'] as Timestamp?,
      featureFlags: mergedFlags,
    );
  }
}