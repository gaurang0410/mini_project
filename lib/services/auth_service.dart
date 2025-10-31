import 'package:cloud_firestore/cloud_firestore.dart'; // Add Firestore import
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Add Firestore instance

  // --- MODIFIED Sign Up ---
  Future<User?> signUpWithEmailPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;

      // *** NEW: Create user document in Firestore on successful sign-up ***
      if (user != null) {
        await _createUserDocument(user.uid, email);
      }
      return user;
    } on FirebaseAuthException catch (e) {
      print("Sign Up Error: $e"); // Keep logging errors
      return null;
    }
  }

  // --- NEW Helper Function to Create User Document ---
  Future<void> _createUserDocument(String uid, String email) async {
    // Determine role based on email (as per mini.docx)
    String role = "user"; // Default role
    
    // --- IMPORTANT: SET YOUR STUDENT ADMIN EMAIL HERE ---
    const String studentAdminEmail = "gaurangkhanolkar.gk@gmail.com"; // <<<--- REPLACE THIS
    // ----------------------------------------------------

    if (email.toLowerCase() == "vpg@gmail.com" || email.toLowerCase() == studentAdminEmail.toLowerCase()) {
      role = "admin";
    }

    await _firestore.collection('users').doc(uid).set({
      'email': email,
      'role': role, // Set role ('user' or 'admin')
      'premium': false, // Default premium status
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }


  // --- Sign In (No changes needed) ---
  Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return result.user;
    } on FirebaseAuthException catch (e) {
       print("Sign In Error: $e");
      return null;
    }
  }

  // --- Google Sign In (Modified to handle user doc) ---
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User cancelled

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;

      // *** NEW: Check if user doc exists, create if not (for Google sign-in) ***
      if (user != null) {
        final docRef = _firestore.collection('users').doc(user.uid);
        final docSnap = await docRef.get();
        if (!docSnap.exists) {
          // If the user signed in with Google for the first time
          await _createUserDocument(user.uid, user.email ?? 'unknown_google_email');
        } else {
           // Optional: Update updatedAt timestamp on login
           await docRef.update({'updatedAt': FieldValue.serverTimestamp()});
        }
      }
      return user;
    } catch (e) {
      print("Google Sign-in Error: $e");
      return null;
    }
  }

  // --- Sign Out (No changes needed) ---
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
