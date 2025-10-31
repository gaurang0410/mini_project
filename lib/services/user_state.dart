import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

// --- Imports for VIP Currency Logic ---
import '../data/currency_list.dart';
import '../data/non_vip.dart';
import '../models/currency.dart';

class UserState extends ChangeNotifier {
  UserModel? _currentUserModel;
  bool _isLoading = true;
  Map<String, dynamic> _featureFlags = {};

  // Public getters
  UserModel? get currentUser => _currentUserModel;
  bool get isLoading => _isLoading;
  bool get isAdmin => _currentUserModel?.role == 'admin';
  bool get isVip => _currentUserModel?.isPremium ?? false;
  bool get isLoggedIn => _currentUserModel != null;
  bool get isGuest => _currentUserModel == null;

  List<Currency> get availableCurrencies {
    if (isVip || isAdmin) {
      return currencies;
    }
    return freeCurrencies;
  }

  Map<String, dynamic> get featureFlags => _featureFlags;
  bool get isNewUiEnabled => _featureFlags['isNewUIEnabled'] ?? false;

  UserState() {
    FirebaseAuth.instance.authStateChanges().listen(_handleAuthStateChange);
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    // No need to manually set _currentUserModel to null,
    // the authStateChanges listener will handle it.
  }

  Future<void> _handleAuthStateChange(User? user) async {
    print("--- [UserState] Auth State Changed. User: ${user?.uid} ---");
    // Keep isLoading true until *everything* is fetched or fails
    if (!_isLoading) {
      _isLoading = true;
      // Notify immediately to show loading spinner during fetches
      notifyListeners();
    }


    // Reset state before fetching
    _currentUserModel = null;
    _featureFlags = {};

    // Fetch feature flags regardless of login state
    try {
      DocumentSnapshot flagsDoc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('features')
          .get();
      if (flagsDoc.exists) {
        _featureFlags = flagsDoc.data() as Map<String, dynamic>;
        print("--- [UserState] Fetched feature flags: $_featureFlags ---");
      } else {
        print("--- [UserState] 'app_config/features' doc does not exist. Using defaults. ---");
      }
    } catch (e) {
      print("--- [UserState] ERROR fetching feature flags: $e. Using defaults. ---");
    }

    // Now, handle user data fetching ONLY if a user is detected by Auth
    if (user == null) {
      print("--- [UserState] User is null (logged out). Setting state to guest. ---");
      // _currentUserModel is already null
    } else {
      print("--- [UserState] User ${user.uid} detected. Attempting to fetch Firestore document... ---");
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          print("--- [UserState] Firestore document FOUND for ${user.uid}. Parsing data... ---");
          _currentUserModel = UserModel.fromFirestore(userDoc, _featureFlags);
          print("--- [UserState] User data loaded successfully: Role=${_currentUserModel?.role}, Premium=${_currentUserModel?.isPremium}. ---");
        } else {
          // --- FIX: Document NOT found ---
          print("--- [UserState] CRITICAL ERROR: Firestore document NOT FOUND for UID: ${user.uid}. ---");
          print("--- [UserState] The user is authenticated, but their data is missing in Firestore. ---");
          print("--- [UserState] Keeping user logged in, but state might be incomplete. Check Firestore Console or signup logic. ---");
          // _currentUserModel remains null in this error case, but we DON'T sign them out.
          // You might want to create a default UserModel here or show a specific error screen.
          // For now, they will appear logged out in the UI because _currentUserModel is null.
          // await FirebaseAuth.instance.signOut(); // <-- REMOVED THIS PROBLEMATIC LINE
        }
      } catch (e) {
         // Error fetching document (e.g., permissions)
         print("--- [UserState] ERROR fetching Firestore document for ${user.uid}: $e. ---");
         print("--- [UserState] Keeping user logged in, but state is incomplete. Check Firestore Rules or connection. ---");
         // _currentUserModel remains null
      }
    }

    // Finally, set loading to false and notify listeners
    _isLoading = false;
    notifyListeners();
    print("--- [UserState] State update finished. User model is ${_currentUserModel == null ? 'null (Guest/Error)' : 'set'}. isLoading: $_isLoading. Notifying listeners. ---");
  }


  // Manual refresh method
  Future<void> refreshUserData() async {
     User? user = FirebaseAuth.instance.currentUser;
     print("--- [UserState] Manual refresh triggered for ${user?.uid}. ---");
     await _handleAuthStateChange(user); // Re-run the handler
  }
}